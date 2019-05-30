package executor

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"

	"k8s.io/klog"
)

type Executor interface {
	Command(cmd string, args ...string) error
	CommandStdout(cmd string, args ...string) ([]byte, error)
	CommandEnv(cmd string, env []string, args ...string) ([]byte, error)

	WriteFile(path string, data []byte, perm os.FileMode) error
	Stat(path string) (os.FileInfo, error)
}

func NewExecutor() Executor {
	return &realExecutor{}
}

func NewDummyExecutor() Executor {
	return &dummyExecutor{}
}

type realExecutor struct{}

func (e *realExecutor) Command(cmd string, args ...string) error {
	_, err := e.CommandStdout(cmd, args...)
	return err
}

func (e *realExecutor) CommandEnv(cmd string, env []string, args ...string) ([]byte, error) {
	klog.V(4).Infof("running command: %s %s env=%v", cmd, strings.Join(args, " "), env)
	command := exec.Command(cmd, args...)
	command.Env = append(os.Environ(), env...)
	out, err := command.CombinedOutput()
	klog.V(4).Infof("output: of %s %s: %s", cmd, strings.Join(args, " "), string(out))
	if err != nil {
		return nil, fmt.Errorf("error running %s %s: %v", err, cmd, strings.Join(args, " "))
	}
	return out, nil
}

func (e *realExecutor) CommandStdout(cmd string, args ...string) ([]byte, error) {
	return e.CommandEnv(cmd, []string{}, args...)
}

func (e *realExecutor) WriteFile(path string, data []byte, perm os.FileMode) error {
	if err := ioutil.WriteFile(path, data, perm); err != nil {
		return fmt.Errorf("error wrinting file (%d) %s: %v", perm, path, err)
	}

	return nil
}

func (e *realExecutor) Stat(path string) (os.FileInfo, error) {
	return os.Stat(path)
}

type dummyExecutor struct{}

func (e *dummyExecutor) WriteFile(path string, data []byte, perm os.FileMode) error {
	klog.V(4).Infof("dry writing file (%d) %s: %s", perm, path, string(data))
	return nil
}

func (e *dummyExecutor) CommandStdout(cmd string, args ...string) ([]byte, error) {
	exec := NewExecutor()
	return exec.CommandStdout(cmd, args...)
}

func (e *dummyExecutor) Command(cmd string, args ...string) error {
	klog.V(4).Infof("dry running command: %s %s", cmd, strings.Join(args, " "))
	return nil
}

func (e *dummyExecutor) CommandEnv(cmd string, env []string, args ...string) ([]byte, error) {
	klog.V(4).Infof("dry running command: %s %s env=%v", cmd, strings.Join(args, " "), env)
	return nil, nil
}

func (e *dummyExecutor) Stat(path string) (os.FileInfo, error) {
	return os.Stat(path)
}
